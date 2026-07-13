#pragma once

#include <string>

namespace shield {

/// Read a system property via __system_property_get (bypasses Java hooks).
std::string getSystemProperty(const char* name);

} // namespace shield
