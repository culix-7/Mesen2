#include "pch.h"
#include "Debugger/CodeDataLogger.h"
#include "Debugger/Debugger.h"
#include "CppUnitTest.h"

#include <algorithm>

using namespace Microsoft::VisualStudio::CppUnitTestFramework;

namespace Test_Debugger
{
	class TestLogger : public CodeDataLogger
	{
	public:
		TestLogger(uint32_t memSize = 0x100, uint32_t romCrc = 0)
			: CodeDataLogger(nullptr, MemoryType::SnesPrgRom, memSize, CpuType::Snes, romCrc)
		{
		}
	};

	TEST_CLASS(Test_CodeDataLogger)
	{

	public:

		TEST_METHOD(Constructor_Memsize_Large_Does_Not_Crash)
		{
			constexpr uint32_t largeSize = 0xFFFFFFFF;
			TestLogger logger(largeSize);
			Assert::IsNotNull(logger.GetRawData(), L"Data not set");
		}

		TEST_METHOD(Constructor_Memsize_Zero_Does_Not_Crash)
		{
			constexpr uint32_t zeroSize = 0;
			TestLogger logger(zeroSize);
			Assert::IsNotNull(logger.GetRawData(), L"Data not set");
		}

		TEST_METHOD(Constructor_Null_Debugger_Does_Not_Crash)
		{
			TestLogger logger(0x100);
			Assert::IsNotNull(logger.GetRawData(), L"Raw data buffer should be allocated even with null debugger");
		}
		TEST_METHOD(IsCode_Addr_Outside_Memsize_Clamps)
		{
			constexpr uint32_t memSize = 0x100;
			TestLogger logger(memSize);
			constexpr uint32_t dangerousAddr = 0xFFFFFFFF;
			Assert::IsFalse(logger.IsCode(dangerousAddr), L"crashed or returned garbage for high address");
		}
		TEST_METHOD(IsData_Addr_Outside_Memsize_Clamps)
		{
			constexpr uint32_t memSize = 0x100;
			TestLogger logger(memSize);
			constexpr uint32_t dangerousAddr = 0xFFFFFFFF;
			Assert::IsFalse(logger.IsData(dangerousAddr), L"crashed or returned garbage for high address");
		}

		TEST_METHOD(IsJumpTarget_Addr_Outside_Memsize_Clamps)
		{
			constexpr uint32_t memSize = 0x100;
			TestLogger logger(memSize);
			constexpr uint32_t dangerousAddr = 0xFFFFFFFF;
			Assert::IsFalse(logger.IsJumpTarget(dangerousAddr), L"crashed or returned garbage for high address");
		}
		TEST_METHOD(IsSubEntryPoint_Addr_Outside_Memsize_Clamps)
		{
			constexpr uint32_t memSize = 0x100;
			TestLogger logger(memSize);
			constexpr uint32_t dangerousAddr = 0xFFFFFFFF;
			Assert::IsFalse(logger.IsSubEntryPoint(dangerousAddr), L"crashed or returned garbage for high address");
		}

		TEST_METHOD(SetCdlData_Length_Greater_Than_Memsize_Does_Not_Crash)
		{
			constexpr uint32_t memSize = 0x100;
			TestLogger logger(memSize);

			uint8_t sourceData[] = { 0xAA, 0xBB, 0xCC, 0xDD };

			logger.SetCdlData(sourceData, 0xFFFFFFFF);
			const uint8_t* internalData = logger.GetRawData();
			for(uint32_t i = 0; i < memSize; i++) {
				Assert::AreEqual((uint8_t)0, internalData[i], L"Data was modified despite invalid length");
			}
		}

		TEST_METHOD(SetCdlData_Null_Pointer_Does_Not_Crash)
		{
			constexpr uint32_t memSize = 0x100;
			TestLogger logger(memSize);

			logger.SetCdlData(nullptr, 1);
			Assert::IsTrue(true, L"SetCdlData did not crash.");
		}
	};
}
