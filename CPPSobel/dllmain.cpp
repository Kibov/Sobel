// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"
#include <iostream>
#include <cmath>

#define Expo extern "C" __declspec(dllexport)


int* Vertical(BYTE* Array, int imageHeight, int imageWidth, int bytesToCalculate)
{
	//GX MATRIX:
	//1  0 -1
	//2  0 -2
	//1  0 -1

	int* GX = new int[bytesToCalculate];

	for (int i = 0; i < bytesToCalculate; i++) GX[i] = 0;

	for (int i = 0; i < bytesToCalculate; i++)
	{
		int row = (i - i % imageWidth) / imageWidth;

		if (i % imageWidth == 0 || i % imageWidth == imageWidth - 1 || row == 0) continue;
		else if (row == imageHeight - 1) break;

		GX[i] = Array[i + 1] * -2 + Array[i - 1] * 2 +
			Array[i + 1 - imageWidth] * -1 + Array[i - 1 - imageWidth] * 1 +
			Array[i + 1 + imageWidth] * -1 + Array[i + 1 - imageWidth] * 1;
	}

	return GX;
}

int* Horizontal(BYTE* Array, int imageHeight, int imageWidth, int bytesToCalculate)
{
	//GY MATRIX:	
	// 1  2  1
	// 0  0  0
	//-1 -2 -1

	int* GY = new int[bytesToCalculate];

	for (int i = 0; i < bytesToCalculate; i++) GY[i] = 0;

	for (int i = 0; i < bytesToCalculate; i++)
	{
		int row = (i - i % imageWidth) / imageWidth;

		if (i % imageWidth == 0 || i % imageWidth == imageWidth - 1 || row == 0) continue;
		else if (row == imageHeight - 1) break;

		GY[i] = Array[i + imageWidth] * -2 + Array[i - imageWidth] * 2 +
			Array[i - 1 + imageWidth] * -1 + Array[i - 1 - imageWidth] * 1 +
			Array[i + 1 + imageWidth] * -1 + Array[i + 1 - imageWidth] * 1;

	}

	return GY;
}

Expo void SobelCPP(BYTE* grayArray, int* calculatedArray, int imageHeight, int imageWidth, int bytesToCalculate )
{

	int* Sobel_GX = Vertical(grayArray, imageHeight, imageWidth, bytesToCalculate);
	int* Sobel_GY = Horizontal(grayArray, imageHeight, imageWidth, bytesToCalculate);

	for (int i = 0; i < bytesToCalculate; i++)
	{
		calculatedArray[i] = std::sqrt(pow(Sobel_GX[i], 2) + pow(Sobel_GY[i], 2));
	}

	delete[] Sobel_GX;
	delete[] Sobel_GY;
}





BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

