#ifndef _WARNINGS_ERRORS_H_
#define _WARNINGS_ERRORS_H_

#include <simgear/compiler.h>

#include <string>
#include <cstdlib>

SG_NO_RETURN void uiuc_warnings_errors(int errorCode, std::string line);

#endif  //_WARNINGS_ERRORS_H_
