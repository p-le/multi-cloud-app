from multiprocessing import Process, Value
from ctypes import c_bool
from random import random
from time import sleep


class CpuBurner:
    """
    Object to asynchronously burn CPU cycles to simulate high CPU load.
    Burns CPU in a separate process and can be toggled on and off.
    """
    def __init__(self):
        self._toggle = Value(c_bool, False, lock=True)
        self._process = Process(target=self._burn_cpu)
        self._process.start()

    def start(self):
        """Start burning CPU."""
        self._toggle.value = True

    def stop(self):
        """Stop burning CPU."""
        self._toggle.value = False

    def is_running(self):
        """Returns true if currently burning CPU."""
        return self._toggle.value

    def _burn_cpu(self):
        """Burn CPU cycles if work is toggled, otherwise sleep."""
        while True:
            if not self._toggle.value:
                sleep(2)
            random()*random()
