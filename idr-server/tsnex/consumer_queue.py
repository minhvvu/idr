# ConsumerQueue.py
# a Singleton class that holds the intermediate data
# produced by TSNE in each iteration

import queue


class ConsumerQueue(object):
    """ A queue that stores all intermediate result of TSNE
        Each element in queue is waiting to be sent to client
        Singleton implementation from:
        http://python-3-patterns-idioms-test.readthedocs.io/en/latest/Singleton.html
    """

    __instance = None

    callback = None
    dataQueue = queue.Queue()
    dataCount = 0

    isPaused = False

    def __new__(cls, val):
        if ConsumerQueue.__instance is None:
            ConsumerQueue.__instance = object.__new__(cls)

        ConsumerQueue.__instance.val = val
        return ConsumerQueue.__instance

    def registerCallback(self, callback):
        print("Register callback: ", callback)
        self.callback = callback

    def push(self, item):
        self.dataQueue.put(item)
        self.dataCount += 1
        if self.callback is not None:
            self.callback()
        else:
            print("[Error] Callback is not available")

    def pop(self):
        value = self.dataQueue.get() if not self.dataQueue.empty() else None
        return value

    def togglePause(self):
        self.isPaused = not self.isPaused
        print("Server is paused!" if self.isPaused else "Server is running!")
