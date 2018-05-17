# Simple Makefile

CUDA_PATH?=/usr/local/cuda
INCLUDES = -I$(CUDA_PATH)/include -I./cuda-ssl/include/
LIB_PATH = $(CUDA_PATH)/lib
HOST_COMPILER ?= g++
NVCC          := $(CUDA_PATH)/bin/nvcc -ccbin $(HOST_COMPILER)
CFLAGS = -I$(INCLUDE_PATH) -L$(LIB_PATH) -lcudart


# **************************************************************************

all: build

build: hashcrack.run 

# hashcrack.o: hashcrack.cu
# 	$(NVCC) $(INCLUDES) -o $@ -c $<

# hashcrack: hashcrack.o
# 	$(NVCC) $(ALL_LDFLAGS) -o $@ $+ $(LIBRARIES)

# hashcrack: hashcrack.cu
# 	$(NVCC) $(INCLUDES) -L$(LIB_PATH) -lcudart -o $@ $+ ./cuda-ssl/md5.o


hashcrack.run: hashcrack.cu
	$(NVCC) $(INCLUDES) -L$(LIB_PATH) -lcudart -o $@ $+
	
clean:
	rm -f hashcrack.run
