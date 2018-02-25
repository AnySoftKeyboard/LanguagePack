import os
import sys
import errno

def eprint(s):
    print(s, file=sys.stderr)
    sys.stderr.flush()


def my_dir():
    return os.path.dirname(os.path.abspath(__file__))


def read_my_dir(fname):
    path = os.path.join(my_dir(), fname)
    ret = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                yield line

def mkdir_p(path):
    '''Works like `mkdir -p`: creates all (not yet existing) directories in a
    given path.'''
    if not path:
        return

    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise
