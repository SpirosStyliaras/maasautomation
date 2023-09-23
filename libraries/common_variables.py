import os


# Common Variables
COMMON_VAR_DICT = {'RESOURCES': os.path.join(os.path.abspath(''), 'resources'),
                   'LIBRARIES': os.path.join(os.path.abspath(''), 'libraries')
}


# Return variables as dictionary
def get_variables():
    """ Get project's common variables """

    return dict(COMMON_VAR_DICT.items())

