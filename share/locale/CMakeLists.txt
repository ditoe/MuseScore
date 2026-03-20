# SPDX-License-Identifier: GPL-3.0-only
# MuseScore-Studio-CLA-applies
#
# MuseScore Studio
# Music Composition & Notation
#
# Copyright (C) 2021 MuseScore Limited
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

file(GLOB TS_FILES CONFIGURE_DEPENDS ${CMAKE_CURRENT_LIST_DIR}/*.ts)

if (MUE_RUN_LRELEASE)
    add_custom_target(translations ALL
        COMMENT "Generating .qm files" VERBATIM
    )

    qt_add_lrelease(translations TS_FILES ${TS_FILES} NO_GLOBAL_TARGET QM_FILES_OUTPUT_VARIABLE QM_FILES)
endif()

install(FILES
    ${CMAKE_CURRENT_LIST_DIR}/languages.json
    # ${QM_FILES}
    DESTINATION ${Mscore_SHARE_NAME}${Mscore_INSTALL_NAME}locale
)

# Install QM files, filtering out any that don't exist or are empty
if (MUE_RUN_LRELEASE)
    install(CODE "
        file(GLOB QM_FILES \"${CMAKE_CURRENT_BINARY_DIR}/*.qm\")
        foreach(qm_file IN LISTS QM_FILES)
            file(SIZE \"\${qm_file}\" file_size)
            if(file_size GREATER 0)
                file(INSTALL \"\${qm_file}\" DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${Mscore_SHARE_NAME}${Mscore_INSTALL_NAME}locale\")
            endif()
        endforeach()
    ")
endif()

install(DIRECTORY ${QT_INSTALL_PREFIX}/translations/
    DESTINATION ${Mscore_SHARE_NAME}${Mscore_INSTALL_NAME}locale
    FILES_MATCHING
    REGEX "qt_.*\\.qm"
    REGEX "qt_help_.*\\.qm" EXCLUDE
    REGEX "qtbase_.*\\.qm"
    REGEX "qt*_en\\.qm" EXCLUDE)
