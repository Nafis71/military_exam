#include "property_reader.h"

#include <sys/system_properties.h>

namespace shield {

std::string getSystemProperty(const char* name) {
    if (name == nullptr) return {};
    char value[PROP_VALUE_MAX] = {};
    if (__system_property_get(name, value) <= 0) return {};
    return std::string(value);
}

} // namespace shield
