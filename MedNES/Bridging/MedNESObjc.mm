//
//  StikNESObjC.m
//  StikNES
//
//  Created by Stossy11 on 12/21/2024.
//  Fixed by 0-Blu
//

#import <Foundation/Foundation.h>
#include <SDL2/SDL.h>

#include <chrono>
#include <iostream>
#include <map>

#include "../Core/6502.hpp"
#include "../Core/Controller.hpp"
#include "../Core/Mapper/Mapper.hpp"
#include "../Core/PPU.hpp"
#include "../Core/ROM.hpp"

int startEmu(NSString* gamePath) {
    std::string romPath = std::string([gamePath UTF8String]);

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) < 0) {
        std::cout << "SDL could not initialize: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_GameController *con = nullptr;
    for (int i = 0; i < SDL_NumJoysticks(); i++) {
        if (SDL_IsGameController(i)) {
            con = SDL_GameControllerOpen(i);
            std::cout << "Controller detected." << std::endl;
            break;
        }
    }

    std::map<int, int> map;
    map[SDL_CONTROLLER_BUTTON_A]      = SDLK_a;
    map[SDL_CONTROLLER_BUTTON_B]      = SDLK_b;
    map[SDL_CONTROLLER_BUTTON_START]  = SDLK_RETURN;
    map[SDL_CONTROLLER_BUTTON_DPAD_UP]    = SDLK_UP;
    map[SDL_CONTROLLER_BUTTON_DPAD_DOWN]  = SDLK_DOWN;
    map[SDL_CONTROLLER_BUTTON_DPAD_LEFT]  = SDLK_LEFT;
    map[SDL_CONTROLLER_BUTTON_DPAD_RIGHT] = SDLK_RIGHT;

    SDL_Window *window;
    std::string window_title = "MedNES";

    int window_width = 1024;
    int window_height = (window_width * 3) / 4;

    window = SDL_CreateWindow(
        window_title.c_str(),
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        window_width,
        window_height,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    if (!window) {
        std::cout << "Could not create window: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        std::cout << "Could not create renderer: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_RenderSetLogicalSize(renderer, 256, 240);

    MedNES::ROM rom;
    rom.open(romPath);
    rom.printHeader();
    MedNES::Mapper *mapper = rom.getMapper();
    if (!mapper) {
        std::cout << "Unknown mapper." << std::endl;
        return 1;
    }

    auto ppu = MedNES::PPU(mapper);
    MedNES::Controller controller;
    auto cpu = MedNES::CPU6502(mapper, &ppu, &controller);
    cpu.reset();

    SDL_Texture *texture = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STATIC,
        256,
        240
    );

    int nmiCounter = 0;
    float duration = 0;
    auto t1 = std::chrono::high_resolution_clock::now();
    bool is_running = true;
    SDL_Event event;

    while (is_running) {
        cpu.step();

        if (ppu.generateFrame) {
            while (SDL_PollEvent(&event)) {
                switch (event.type) {
                    case SDL_CONTROLLERBUTTONDOWN:
                        controller.setButtonPressed(map[event.cbutton.button], true);
                        break;
                    case SDL_CONTROLLERBUTTONUP:
                        controller.setButtonPressed(map[event.cbutton.button], false);
                        break;
                    case SDL_KEYDOWN:
                        controller.setButtonPressed(event.key.keysym.sym, true);
                        break;
                    case SDL_KEYUP:
                        controller.setButtonPressed(event.key.keysym.sym, false);
                        break;
                    case SDL_QUIT:
                        is_running = false;
                        break;

                    case SDL_WINDOWEVENT:
                        if (event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED ||
                            event.window.event == SDL_WINDOWEVENT_RESIZED) {
                        }
                        break;

                    default:
                        break;
                }
            }

            nmiCounter++;
            auto t2 = std::chrono::high_resolution_clock::now();
            duration += std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
            t1 = std::chrono::high_resolution_clock::now();

            if (nmiCounter == 10) {
                float avgFps = 1000.0f / (duration / nmiCounter);
                std::string fpsTitle = window_title + " (FPS: " + std::to_string((int)avgFps) + ")";
                SDL_SetWindowTitle(window, fpsTitle.c_str());
                nmiCounter = 0;
                duration = 0;
            }

            ppu.generateFrame = false;
            SDL_UpdateTexture(texture, nullptr, ppu.buffer, 256 * sizeof(Uint32));
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, nullptr, nullptr);
            SDL_RenderPresent(renderer);
        }
    }

    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
