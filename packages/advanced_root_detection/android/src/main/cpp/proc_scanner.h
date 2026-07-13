#pragma once
#include <vector>
#include <string>

namespace shield {
    std::vector<std::string> scanMapsForHooks();
    bool hasFridaAnonymousMapping();
    /** Find Zygisk/Magisk libraries via the dynamic linker's own table (dl_iterate_phdr). */
    bool detectInjectedLibraries();
    /** Find anonymous rwxp (read+write+exec) pages — injected shellcode/Zygisk modules. */
    bool detectAnonymousExecMappings();
} // namespace shield
