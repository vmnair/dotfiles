# create a makefile for the project
# Author: Vinod Nair
# Date: 02/15/2025
# Description: This makefile is used to compile the project
#
# Usage: make [TARGET]
# TARGET: hello - compile hello.c
# 			 clean - remove all compiled files
# 			 run - run the compiled file
# 			 all - compile all files

.DEFAULT_GOAL := build

.PHONY:fmt vet clean build
fmt:
	@go fmt ./...

vet: fmt
	@go vet ./...

clean:
	@rm -f hello_world

build: vet
	@go build
	@echo "Build successful"
