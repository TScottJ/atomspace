#
# Definitions for automatically building the atom_types files, given
# a master file "atom_types.script" that defines all of the type
# relationships.
# Macro example call:
# OPENCOG_ADD_ATOM_TYPES(
#        SCRIPT_FILE
#        HEADER_FILE
#        DEFINITIONS_FILE
#        INHERITANCE_FILE
#        SCM_FILE
#        PYTHON_FILE)
#
IF (NOT SCRIPT_FILE)
    MESSAGE(FATAL_ERROR "OPENCOG_ADD_ATOM_TYPES missing SCRIPT_FILE")
ENDIF (NOT SCRIPT_FILE)

IF (NOT HEADER_FILE)
    MESSAGE(FATAL_ERROR "OPENCOG_ADD_ATOM_TYPES missing HEADER_FILE")
ENDIF (NOT HEADER_FILE)

IF (NOT DEFINITIONS_FILE)
    MESSAGE(FATAL_ERROR "OPENCOG_ADD_ATOM_TYPES missing DEFINITIONS_FILE")
ENDIF (NOT DEFINITIONS_FILE)

IF (NOT INHERITANCE_FILE)
    MESSAGE(FATAL_ERROR "OPENCOG_ADD_ATOM_TYPES missing INHERITANCE_FILE")
ENDIF (NOT INHERITANCE_FILE)

IF (NOT SCM_FILE)
    MESSAGE(FATAL_ERROR "OPENCOG_ADD_ATOM_TYPES missing SCM_FILE")
ENDIF (NOT SCM_FILE)

IF (NOT PYTHON_FILE)
    MESSAGE(FATAL_ERROR "OPENCOG_ADD_ATOM_TYPES missing PYTHON_FILE")
ENDIF (NOT PYTHON_FILE)


SET(CLASSSERVER_REFERENCE "opencog::classserver().")
SET(CLASSSERVER_INSTANCE "opencog::classserver()")

FILE(WRITE "${HEADER_FILE}" "/* File automatically generated by the macro OPENCOG_ADD_ATOM_TYPES. Do not edit */\n")
FILE(APPEND "${HEADER_FILE}"  "#include <opencog/atoms/base/types.h>\nnamespace opencog\n{\n")
FILE(WRITE "${DEFINITIONS_FILE}"  "/* File automatically generated by the macro OPENCOG_ADD_ATOM_TYPES. Do not edit */\n#include <opencog/atoms/base/ClassServer.h>\n#include <opencog/atoms/base/atom_types.h>\n#include <opencog/atoms/base/types.h>\n#include \"atom_types.h\"\n")
FILE(WRITE "${INHERITANCE_FILE}"  "/* File automatically generated by the macro OPENCOG_ADD_ATOM_TYPES. Do not edit */\n")

# We need to touch the class-server before doing anything.
# This is in order to guarantee that the main atomspace types
# get created before other derived types.
#
# There's still a potentially nasty bug here: if some third types.script
# file depends on types defined in a second file, but the third initializer
# runs before the second, then any atoms in that third file that inherit
# from the second will get a type of zero.  This will crash code later on.
# The only fix for this is to make sure that the third script forces the
# initailzers for the second one to run first. Hopefully, the programmer
# will figure this out, before the bug shows up. :-)
FILE(APPEND "${INHERITANCE_FILE}" "/* Touch the server before adding types. */\n")
FILE(APPEND "${INHERITANCE_FILE}" "${CLASSSERVER_INSTANCE};\n")

FILE(WRITE "${SCM_FILE}" "\n")
FILE(APPEND "${SCM_FILE}" "; DO NOT EDIT THIS FILE! This file was automatically\n")
FILE(APPEND "${SCM_FILE}" "; generated from atom definitions in types.script by the macro OPENCOG_ADD_ATOM_TYPES\n")
FILE(APPEND "${SCM_FILE}" ";\n")
FILE(APPEND "${SCM_FILE}" "; This file contains basic scheme wrappers for atom creation.\n")
FILE(APPEND "${SCM_FILE}" ";\n")
FILE(APPEND "${SCM_FILE}" "(define-module (opencog))\n")

FILE(WRITE "${PYTHON_FILE}" "\n")
FILE(APPEND "${PYTHON_FILE}" "# DO NOT EDIT THIS FILE! This file was automatically generated from atom\n")
FILE(APPEND "${PYTHON_FILE}" "# definitions in types.script by the macro OPENCOG_ADD_ATOM_TYPES\n")
FILE(APPEND "${PYTHON_FILE}" "#\n")
FILE(APPEND "${PYTHON_FILE}" "# This file contains basic python wrappers for atom creation.\n")
FILE(APPEND "${PYTHON_FILE}" "#\n")
FILE(APPEND "${PYTHON_FILE}" "from opencog.atomspace import TruthValue\n")
FILE(APPEND "${PYTHON_FILE}" "\n")

FILE(STRINGS "${SCRIPT_FILE}" TYPE_SCRIPT_CONTENTS)
FOREACH (LINE ${TYPE_SCRIPT_CONTENTS})
    # this regular expression is more complex than required due to cmake's
    # regex engine bugs
    STRING(REGEX MATCH "^[ 	]*([A-Z_]+)?([ 	]*<-[ 	]*([A-Z_, 	]+))?[ 	]*(\"[A-Za-z]*\")?[ 	]*(//.*)?[ 	]*$" MATCHED "${LINE}")
    IF (MATCHED AND CMAKE_MATCH_1)
        SET(TYPE ${CMAKE_MATCH_1})
        SET(PARENT_TYPES ${CMAKE_MATCH_3})
        SET(TYPE_NAME "")
        IF (CMAKE_MATCH_4)
            MESSAGE(STATUS "Custom atom type name specified: ${CMAKE_MATCH_4}")
            STRING(REGEX MATCHALL "." CHARS ${CMAKE_MATCH_4})
            LIST(LENGTH CHARS LIST_LENGTH)
            MATH(EXPR LAST_INDEX "${LIST_LENGTH} - 1")
            FOREACH(I RANGE ${LAST_INDEX})
                LIST(GET CHARS ${I} C)
                IF (NOT ${C} STREQUAL "\"")
                    SET(TYPE_NAME "${TYPE_NAME}${C}")
                ENDIF (NOT ${C} STREQUAL "\"")
            ENDFOREACH(I RANGE ${LIST_LENGTH})
        ENDIF (CMAKE_MATCH_4)

        IF (NOT "${TYPE}" STREQUAL "NOTYPE")
            FILE(APPEND "${HEADER_FILE}" "extern opencog::Type ${TYPE};\n")
            FILE(APPEND "${DEFINITIONS_FILE}"  "opencog::Type opencog::${TYPE};\n")
        ELSE (NOT "${TYPE}" STREQUAL "NOTYPE")
            FILE(APPEND "${HEADER_FILE}"  "#ifndef _OPENCOG_NOTYPE_\n#define _OPENCOG_NOTYPE_\n")
            FILE(APPEND "${HEADER_FILE}"  "// Set notype's code with the last possible Type code\n")
            FILE(APPEND "${HEADER_FILE}"  "static const opencog::Type ${TYPE}=((Type) -1);\n")
            FILE(APPEND "${HEADER_FILE}"  "#endif // _OPENCOG_NOTYPE_\n")
        ENDIF (NOT "${TYPE}" STREQUAL "NOTYPE")

        IF (TYPE_NAME STREQUAL "")
            # Set type name using camel casing
            STRING(REGEX MATCHALL "." CHARS ${TYPE})
            LIST(LENGTH CHARS LIST_LENGTH)
            MATH(EXPR LAST_INDEX "${LIST_LENGTH} - 1")
            FOREACH(I RANGE ${LAST_INDEX})
                LIST(GET CHARS ${I} C)
                IF (NOT ${C} STREQUAL "_")
                    MATH(EXPR IP "${I} - 1")
                    LIST(GET CHARS ${IP} CP)
                    IF (${I} EQUAL 0)
                        SET(TYPE_NAME "${TYPE_NAME}${C}")
                    ELSE (${I} EQUAL 0)
                        IF (${CP} STREQUAL "_")
                            SET(TYPE_NAME "${TYPE_NAME}${C}")
                        ELSE (${CP} STREQUAL "_")
                            STRING(TOLOWER "${C}" CL)
                            SET(TYPE_NAME "${TYPE_NAME}${CL}")
                        ENDIF (${CP} STREQUAL "_")
                    ENDIF (${I} EQUAL 0)
                ENDIF (NOT ${C} STREQUAL "_")
            ENDFOREACH(I RANGE ${LIST_LENGTH})
        ENDIF (TYPE_NAME STREQUAL "")

        STRING(REGEX REPLACE "([a-zA-Z]*)(Link|Node)$" "\\1" SHORT_NAME ${TYPE_NAME})
        MESSAGE(STATUS "Atom type name: ${TYPE_NAME} ${SHORT_NAME}")

        # Try to guess if the thing is a node or link based on its name
        STRING(REGEX MATCH "NODE$" ISNODE ${TYPE})
        STRING(REGEX MATCH "LINK$" ISLINK ${TYPE})

        # If not named as a node or a link, assume its a link
        # This is kind of hacky, but I don't know what else to do ...
        IF (NOT ISNODE STREQUAL "NODE" AND NOT ISLINK STREQUAL "LINK")
            SET(ISLINK "LINK")
        ENDIF (NOT ISNODE STREQUAL "NODE" AND NOT ISLINK STREQUAL "LINK")

        # Print out the scheme definitions
        FILE(APPEND "${SCM_FILE}" "(define-public ${TYPE_NAME}Type (cog-type->int '${TYPE_NAME}))\n")
        IF (ISNODE STREQUAL "NODE")
            FILE(APPEND "${SCM_FILE}" "(define-public (${TYPE_NAME} . x)\n")
            FILE(APPEND "${SCM_FILE}" "\t(apply cog-new-node (append (list ${TYPE_NAME}Type) x)))\n")
            IF (NOT SHORT_NAME STREQUAL "")
                FILE(APPEND "${SCM_FILE}" "(define-public (${SHORT_NAME} . x)\n")
                FILE(APPEND "${SCM_FILE}" "\t(apply cog-new-node (append (list ${TYPE_NAME}Type) x)))\n")
            ENDIF (NOT SHORT_NAME STREQUAL "")
        ENDIF (ISNODE STREQUAL "NODE")
        IF (ISLINK STREQUAL "LINK")
            FILE(APPEND "${SCM_FILE}" "(define-public (${TYPE_NAME} . x)\n")
            FILE(APPEND "${SCM_FILE}" "\t(apply cog-new-link (append (list ${TYPE_NAME}Type) x)))\n")
            IF (NOT SHORT_NAME STREQUAL "")
                FILE(APPEND "${SCM_FILE}" "(define-public (${SHORT_NAME} . x)\n")
                FILE(APPEND "${SCM_FILE}" "\t(apply cog-new-link (append (list ${TYPE_NAME}Type) x)))\n")
            ENDIF (NOT SHORT_NAME STREQUAL "")
        ENDIF (ISLINK STREQUAL "LINK")

        # Print out the python definitions
        IF (ISNODE STREQUAL "NODE")
            FILE(APPEND "${PYTHON_FILE}" "def ${TYPE_NAME}(node_name, tv=None):\n")
            FILE(APPEND "${PYTHON_FILE}" "    return atomspace.add_node(types.${TYPE_NAME}, node_name, tv)\n")
        ENDIF (ISNODE STREQUAL "NODE")
        IF (ISLINK STREQUAL "LINK")
            FILE(APPEND "${PYTHON_FILE}" "def ${TYPE_NAME}(*args):\n")
            FILE(APPEND "${PYTHON_FILE}" "    return atomspace.add_link(types.${TYPE_NAME}, args)\n")
        ENDIF (ISLINK STREQUAL "LINK")

        IF (PARENT_TYPES)
            STRING(REGEX REPLACE "[ 	]*,[ 	]*" ";" PARENT_TYPES "${PARENT_TYPES}")
            FOREACH (PARENT_TYPE ${PARENT_TYPES})
                # skip inheritance of the special "notype" class; we could move
                # this test up but it was left here for simplicity's sake
                IF (NOT "${TYPE}" STREQUAL "NOTYPE")
                    FILE(APPEND "${INHERITANCE_FILE}" "opencog::${TYPE} = ${CLASSSERVER_REFERENCE}addType(opencog::${PARENT_TYPE}, \"${TYPE_NAME}\");\n")
                ENDIF (NOT "${TYPE}" STREQUAL "NOTYPE")
            ENDFOREACH (PARENT_TYPE)
        ELSE (PARENT_TYPES)
            IF (NOT "${TYPE}" STREQUAL "NOTYPE")
                FILE(APPEND "${INHERITANCE_FILE}" "opencog::${TYPE} = ${CLASSSERVER_REFERENCE}addType(opencog::${TYPE}, \"${TYPE_NAME}\");\n")
            ENDIF (NOT "${TYPE}" STREQUAL "NOTYPE")
        ENDIF (PARENT_TYPES)
    ELSE (MATCHED AND CMAKE_MATCH_1)
        IF (NOT MATCHED)
            FILE(REMOVE "${HEADER_FILE}")
            FILE(REMOVE "${DEFINITIONS_FILE}")
            FILE(REMOVE "${INHERITANCE_FILE}")
            MESSAGE(FATAL_ERROR "Invalid line in ${SCRIPT_FILE} file: [${LINE}]")
        ENDIF (NOT MATCHED)
    ENDIF (MATCHED AND CMAKE_MATCH_1)
ENDFOREACH (LINE)
FILE(APPEND "${HEADER_FILE}" "} // namespace opencog\n")
