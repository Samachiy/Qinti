import psutil
import sys


def main():
    # Retrieve arguments
    args = sys.argv
    print("Received args: " + str(args))
    # removes the path of this script from the arguments
    args.pop(0)

    print("Received pids: " + str(args))
    for arg in args:
        kill_process_and_children(int(arg))


def kill_process_and_children(pid: int, signal: int = 15):
    print("Fetching processes belonging to pid: " + str(pid))
    try:
        process = psutil.Process(pid)
    except psutil.NoSuchProcess as e:
        # Maybe log something here
        return

    for child_process in process.children(recursive=True):
        child_process.send_signal(signal)
        print("killed process: " + str(child_process))

    process.send_signal(signal)
    print("killed process: " + str(process))





if __name__ == "__main__":
    print("Running kill.py")
    main()
