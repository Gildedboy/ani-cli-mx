#!/usr/bin/env python3
"""Exercise the real Lua controller: switching video retains position and pause."""
import json
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

root = Path(__file__).resolve().parents[1]
assert shutil.which('mpv') and shutil.which('ffmpeg'), 'mpv and ffmpeg are required'
with tempfile.TemporaryDirectory(prefix='ani-quality-') as name:
    tmp = Path(name)
    (tmp / 'functions.sh').write_text((root / 'ani-cli-mx-core').read_text().split('# MAIN\n', 1)[0])
    setup = '''. "$TEST_DIR/functions.sh"
mpv_session_player_command_file="$TEST_DIR/command"
mpv_session_player_event_file="$TEST_DIR/event"
mpv_session_player_action_file="$TEST_DIR/action"
mpv_session_player_owner_file="$TEST_DIR/owner"
mpv_session_controller_script="$TEST_DIR/controller.lua"
mpv_session_player_controller_script="$mpv_session_controller_script"
mpv_window_state_player_file="$TEST_DIR/window-state"
mpv_window_state_player_script="$TEST_DIR/window.lua"
create_mpv_session_controller
'''
    import os
    env = dict(os.environ, TEST_DIR=name)
    subprocess.run(['sh', '-c', setup], env=env, check=True)
    (tmp / 'owner').touch()
    video = tmp / 'video.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-f', 'lavfi', '-i', 'testsrc=size=128x72:rate=10',
        '-f', 'lavfi', '-i', 'sine=frequency=440', '-t', '15', '-c:v', 'mpeg4',
        '-pix_fmt', 'yuv420p', '-c:a', 'aac', str(video)], check=True, capture_output=True)
    log = (tmp / 'mpv.log').open('w')
    player = subprocess.Popen(['mpv', '--no-config', '--vo=null', '--ao=null', '--idle=yes',
        '--keep-open=yes', '--input-ipc-server='+str(tmp/'ipc'), '--script='+str(tmp/'controller.lua')],
        stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 10
        while not (tmp/'ipc').exists() and time.monotonic() < deadline:
            time.sleep(.05)
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        connection.settimeout(5)
        connection.connect(str(tmp/'ipc'))
        stream = connection.makefile('rwb')
        request_id = 0
        def ipc(command):
            global request_id
            request_id += 1
            stream.write((json.dumps(dict(command=command, request_id=request_id))+'\n').encode())
            stream.flush()
            while True:
                response = json.loads(stream.readline())
                if response.get('request_id') == request_id:
                    assert response['error'] == 'success', response
                    return response.get('data')
        def queue(keep):
            payload = dict(action='load', episode='s1e1', url=str(video), title='Quality switch',
                referrer='', headers='', subtitles=[], keep_position=keep)
            staged = tmp/'command.new'
            staged.write_text(json.dumps(payload))
            staged.replace(tmp/'command')
        def wait_loaded():
            deadline = time.monotonic()+5
            while time.monotonic() < deadline:
                if not (tmp/'command').exists() and ipc(['get_property', 'path']) == str(video):
                    time.sleep(.3)
                    return
                time.sleep(.05)
            raise AssertionError('controller did not load video')
        queue(False)
        wait_loaded()
        ipc(['set_property', 'pause', True])
        ipc(['seek', 6, 'absolute+exact'])
        time.sleep(.2)
        before = ipc(['get_property', 'time-pos'])
        queue(True)
        wait_loaded()
        after = ipc(['get_property', 'time-pos'])
        assert abs(after-before) < .5, (before, after)
        assert ipc(['get_property', 'pause']) is True
        assert ipc(['get_property', 'audio-codec'])
        queue(False)
        wait_loaded()
        assert ipc(['get_property', 'time-pos']) < 2
        assert ipc(['get_property', 'pause']) is False
        print('Real mpv controller preserved position, pause and audio; ordinary loads start at zero.')
        connection.close()
    finally:
        player.terminate()
        player.wait(timeout=5)
        log.close()
