//
//  MedNESObjc.h
//  MedNES
//
//  Created by Stossy11 on 21/12/2024.
//

#import <Foundation/Foundation.h>
#include <SDL2/SDL.h>
#include <chrono>
#include <map>
#include <string>
#include "../Core/6502.hpp"
#include "../Core/Controller.hpp"
#include "../Core/Mapper/Mapper.hpp"
#include "../Core/PPU.hpp"
#include "../Core/ROM.hpp"




/**
 * @brief Starts the emulator with the given game path.
 *
 * @param gamePath An NSString representing the file path to the game ROM.
 * @return int Status code where 0 indicates success and non-zero indicates an error.
 */
int startEmu(NSString* gamePath);
