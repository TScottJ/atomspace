from cython.operator cimport dereference as deref
from opencog.atomspace cimport cAtomSpace, AtomSpace, Handle, cHandle

# basic wrapping for std::string conversion
cdef extern from "<string>" namespace "std":
    cdef cppclass string:
        string()
        string(char *)
        char * c_str()
        int size()

# This needs to be explicitly initialized...
cdef extern from "opencog/query/PatternSCM.h" namespace "opencog":
    cdef cppclass PatternSCM:
        PatternSCM()

cdef PatternSCM pattern_object
def __init__():
    global pattern_object
    pattern_object = PatternSCM()

# Now actually run it ... 
__init__()

cdef extern from "opencog/cython/opencog/PyScheme.h" namespace "opencog":
    string eval_scheme(cAtomSpace& as, const string& s)

# Returns a string value
def scheme_eval(AtomSpace a, char* s):
    cdef string ret
    cdef string expr
    expr = string(s)
    ret = eval_scheme(deref(a.atomspace), expr)
    return ret.c_str()

cdef extern from "opencog/cython/opencog/PyScheme.h" namespace "opencog":
    cHandle eval_scheme_h(cAtomSpace& as, const string& s)

# Returns a Handle
def scheme_eval_h(AtomSpace a, char* s):
    cdef cHandle ret
    cdef string expr
    expr = string(s)
    ret = eval_scheme_h(deref(a.atomspace), expr)
    return Handle(ret.value())

cdef extern from "opencog/guile/load-file.h" namespace "opencog":
    int load_scm_file (cAtomSpace& as, char* filename)

def load_scm(AtomSpace a, char* fname):
    status = load_scm_file(deref(a.atomspace), fname)
    return status == 0

