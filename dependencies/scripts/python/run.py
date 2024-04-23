import socket
import json
import os
import sys
import subprocess

opened_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
UDP_IP = "127.0.0.1"
UDP_PORT = 7870


def main():
    # Retrieve arguments
    args = sys.argv
    # removes the path of this script from the arguments
    args.pop(0)

    send_packet(["DEBUG", 'Run.py: Attempting to run subprocess with data: ' + ' '.join(args)])
    script_dir = os.path.dirname(args[0]) # We get the path of the target program script so as to run it in it's context
    script_dir = script_dir.strip()
    if script_dir != "":
        os.chdir(script_dir)
    script_process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # send_packet(["PID", int(os.getppid())]) # this pid corresponds to the godot process that calls it, so no need to send it, the calling function already returns it
    target_process_pid = int(script_process.pid)
    print(target_process_pid)
    # send_packet(["PID", target_process_pid]) # The SIGTERM is already propagated to children, so no need for this anymore
    send_packet(["DEBUG", 'Run.py: Running subprocess with data: ' + ' '.join(args)])
    prev_line_empty = False
    line_empty = False
    while True:
        line = script_process.stdout.read1().decode('utf-8')
        is_same_line = line.find("\r") != -1
        line = line.rstrip()
        line_empty = line.strip() == ""

        if script_process.poll() != None:
            send_packet(["END", target_process_pid])
            #time.sleep(1)
            break

        # Oddly specific exceptions
        if "Press any key to continue" in line:
            send_packet(["KEY_REQUEST", line])
            line = "Script requested key input. Handling of the request is not yet implemented."
            send_packet(["DEBUG", line])
            continue

        # Empty lines removal
        if line_empty and prev_line_empty:
            continue

        if is_same_line:
            send_packet(["SAME_LINE", line])
        else:
            send_packet(line)

        prev_line_empty = line_empty


def send_packet(packet):
    print(packet)
    byte_message = bytes(json.dumps(packet), "utf-8")
    opened_socket.sendto(byte_message, (UDP_IP, UDP_PORT))


if __name__ == "__main__":
    main()
