# Configuration file for custom user settings

if(RENESAS_IDE AND RENESAS_IDE STREQUAL "e2studio")
    set(RASC_EXE_PATH "echo")
    message(NOTICE "RENESAS_IDE is defined, so RASC_EXE_PATH set to echo for information purposes")
elseif(DEFINED RASC_EXE_PATH)
    message("Using RASC_EXE_PATH defined via CLI -D: ${RASC_EXE_PATH}")
elseif(DEFINED ENV{RASC_EXE_PATH})
    set(RASC_EXE_PATH $ENV{RASC_EXE_PATH})
    message("Using RASC_EXE_PATH defined in environment: ${RASC_EXE_PATH}")
else ()
    # No override given: auto-detect the newest installed Smart Configurator so
    # this works on any PC regardless of the exact sc_v*/fsp_v* version installed.
    file(GLOB _rasc_candidates
        "C:/Renesas/RA/sc_v*/eclipse/rasc.exe"
        "$ENV{LOCALAPPDATA}/Programs/Renesas/RA/sc_v*/eclipse/rasc.exe")
    if(_rasc_candidates)
        list(SORT _rasc_candidates)
        list(GET _rasc_candidates -1 RASC_EXE_PATH)
        message("Auto-detected RASC_EXE_PATH: ${RASC_EXE_PATH}")
    else()
        set(RASC_EXE_PATH "C:/Renesas/RA/sc_v2025-12_fsp_v6.4.0/eclipse/rasc.exe")
        message("Using RASC_EXE_PATH fallback default: ${RASC_EXE_PATH} "
                "(set RASC_EXE_PATH env var or -DRASC_EXE_PATH= to override)")
    endif()
endif()
