#pragma once

#ifdef _WIN32

#include "CppUnitTest.h"
using namespace Microsoft::VisualStudio::CppUnitTestFramework;

#else

#include <cassert>
#include <fstream>
#include <iostream>
#include <vector>
#include <functional>
#include <string>

// function wrappers so Assert calls can be used on other OS-es
namespace Assert
{
	template<typename T, typename U> inline void AreEqual(T e, U a, const wchar_t* m = 0) { assert(e == a); }
	template<typename T, typename U> inline void AreNotEqual(T e, U a, const wchar_t* m = 0) { assert(e != a); }
	inline void IsNotNull(void* p, const wchar_t* m = 0) { assert(p != nullptr); }
	inline void IsFalse(bool c, const wchar_t* m = 0) { assert(!c); }
	inline void IsTrue(bool c, const wchar_t* m = 0) { assert(c); }
	inline void IsEmpty(std::wstring str) { assert(str.empty()); }
}

// registers all tests so they can be run on other OS-es
struct TestRegistrar
{
	static std::vector<std::pair<std::string, std::function<void()>>>& GetTests()
	{
		static std::vector<std::pair<std::string, std::function<void()>>> tests;
		return tests;
	}
};

// Consumes the entire class block and converts to free functions
#define TEST_CLASS(className) \
  static void Run_##className(); \
  struct className##_Reg { className##_Reg() { TestRegistrar::GetTests().push_back({"" #className "", &Run_##className}); } } className##_reg; \
  static void Run_##className()

#define TEST_METHOD(methodName) static void methodName(); struct methodName##_Reg { methodName##_Reg() { TestRegistrar::GetTests().push_back({"" #methodName "", &methodName}); } } methodName##_reg; static void methodName()

#endif