/*
Author: Andrew DiPrinzio 
Course: EN605.417.FA
Assignment: Final Project
*/
 
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <string>
#include <fstream>
#include <assert.h>

#include <cudassl/md5.h>

#define HASH_LEN_CHAR 16

#define MAX_CHARS 100000

typedef struct {    
    char characters[MAX_CHARS];
    int indicies[MAX_CHARS];
    int results[MAX_CHARS];
} Wordlist;

// Structure that holds program arguments specifying number of threads/blocks
// to use.
typedef struct {    
    std::string hash_list;
    std::string word_list;
} Arguments;

//__constant__ int * d_word_counter;
__constant__ unsigned char d_target_hash[HASH_LEN_CHAR];
static unsigned char h_target_hash[HASH_LEN_CHAR] = {0xC3, 0xFC, 0xD3, 0xD7, 0x61, 0x92, 0xE4, 0x00, 0x7D, 0xFB, 0x49, 0x6C, 0xCA, 0x67, 0xE1, 0x3B};


__device__ void md5_init(md5_context *ctx)
{
    memset(ctx, 0, sizeof(md5_context));
}

__device__ void md5_free(md5_context *ctx)
{
    if (ctx == NULL)
        return;

    zeroize(ctx, sizeof(md5_context));
}

/*
 * MD5 context setup
 */
__device__ void md5_starts(md5_context *ctx)
{
    ctx->total[0] = 0;
    ctx->total[1] = 0;

    ctx->state[0] = 0x67452301;
    ctx->state[1] = 0xEFCDAB89;
    ctx->state[2] = 0x98BADCFE;
    ctx->state[3] = 0x10325476;
}

__device__ void md5_process(md5_context *ctx, const unsigned char data[64])
{
    uint32_t X[16], A, B, C, D;

    GET_UINT32_LE(X[ 0], data,  0);
    GET_UINT32_LE(X[ 1], data,  4);
    GET_UINT32_LE(X[ 2], data,  8);
    GET_UINT32_LE(X[ 3], data, 12);
    GET_UINT32_LE(X[ 4], data, 16);
    GET_UINT32_LE(X[ 5], data, 20);
    GET_UINT32_LE(X[ 6], data, 24);
    GET_UINT32_LE(X[ 7], data, 28);
    GET_UINT32_LE(X[ 8], data, 32);
    GET_UINT32_LE(X[ 9], data, 36);
    GET_UINT32_LE(X[10], data, 40);
    GET_UINT32_LE(X[11], data, 44);
    GET_UINT32_LE(X[12], data, 48);
    GET_UINT32_LE(X[13], data, 52);
    GET_UINT32_LE(X[14], data, 56);
    GET_UINT32_LE(X[15], data, 60);

#define S(x,n) ((x << n) | ((x & 0xFFFFFFFF) >> (32 - n)))

#define P(a,b,c,d,k,s,t)                                \
{                                                       \
    a += F(b,c,d) + X[k] + t; a = S(a,s) + b;           \
}

    A = ctx->state[0];
    B = ctx->state[1];
    C = ctx->state[2];
    D = ctx->state[3];

#define F(x,y,z) (z ^ (x & (y ^ z)))

    P(A, B, C, D,  0,  7, 0xD76AA478);
    P(D, A, B, C,  1, 12, 0xE8C7B756);
    P(C, D, A, B,  2, 17, 0x242070DB);
    P(B, C, D, A,  3, 22, 0xC1BDCEEE);
    P(A, B, C, D,  4,  7, 0xF57C0FAF);
    P(D, A, B, C,  5, 12, 0x4787C62A);
    P(C, D, A, B,  6, 17, 0xA8304613);
    P(B, C, D, A,  7, 22, 0xFD469501);
    P(A, B, C, D,  8,  7, 0x698098D8);
    P(D, A, B, C,  9, 12, 0x8B44F7AF);
    P(C, D, A, B, 10, 17, 0xFFFF5BB1);
    P(B, C, D, A, 11, 22, 0x895CD7BE);
    P(A, B, C, D, 12,  7, 0x6B901122);
    P(D, A, B, C, 13, 12, 0xFD987193);
    P(C, D, A, B, 14, 17, 0xA679438E);
    P(B, C, D, A, 15, 22, 0x49B40821);

#undef F

#define F(x,y,z) (y ^ (z & (x ^ y)))

    P(A, B, C, D,  1,  5, 0xF61E2562);
    P(D, A, B, C,  6,  9, 0xC040B340);
    P(C, D, A, B, 11, 14, 0x265E5A51);
    P(B, C, D, A,  0, 20, 0xE9B6C7AA);
    P(A, B, C, D,  5,  5, 0xD62F105D);
    P(D, A, B, C, 10,  9, 0x02441453);
    P(C, D, A, B, 15, 14, 0xD8A1E681);
    P(B, C, D, A,  4, 20, 0xE7D3FBC8);
    P(A, B, C, D,  9,  5, 0x21E1CDE6);
    P(D, A, B, C, 14,  9, 0xC33707D6);
    P(C, D, A, B,  3, 14, 0xF4D50D87);
    P(B, C, D, A,  8, 20, 0x455A14ED);
    P(A, B, C, D, 13,  5, 0xA9E3E905);
    P(D, A, B, C,  2,  9, 0xFCEFA3F8);
    P(C, D, A, B,  7, 14, 0x676F02D9);
    P(B, C, D, A, 12, 20, 0x8D2A4C8A);

#undef F

#define F(x,y,z) (x ^ y ^ z)

    P(A, B, C, D,  5,  4, 0xFFFA3942);
    P(D, A, B, C,  8, 11, 0x8771F681);
    P(C, D, A, B, 11, 16, 0x6D9D6122);
    P(B, C, D, A, 14, 23, 0xFDE5380C);
    P(A, B, C, D,  1,  4, 0xA4BEEA44);
    P(D, A, B, C,  4, 11, 0x4BDECFA9);
    P(C, D, A, B,  7, 16, 0xF6BB4B60);
    P(B, C, D, A, 10, 23, 0xBEBFBC70);
    P(A, B, C, D, 13,  4, 0x289B7EC6);
    P(D, A, B, C,  0, 11, 0xEAA127FA);
    P(C, D, A, B,  3, 16, 0xD4EF3085);
    P(B, C, D, A,  6, 23, 0x04881D05);
    P(A, B, C, D,  9,  4, 0xD9D4D039);
    P(D, A, B, C, 12, 11, 0xE6DB99E5);
    P(C, D, A, B, 15, 16, 0x1FA27CF8);
    P(B, C, D, A,  2, 23, 0xC4AC5665);

#undef F

#define F(x,y,z) (y ^ (x | ~z))

    P(A, B, C, D,  0,  6, 0xF4292244);
    P(D, A, B, C,  7, 10, 0x432AFF97);
    P(C, D, A, B, 14, 15, 0xAB9423A7);
    P(B, C, D, A,  5, 21, 0xFC93A039);
    P(A, B, C, D, 12,  6, 0x655B59C3);
    P(D, A, B, C,  3, 10, 0x8F0CCC92);
    P(C, D, A, B, 10, 15, 0xFFEFF47D);
    P(B, C, D, A,  1, 21, 0x85845DD1);
    P(A, B, C, D,  8,  6, 0x6FA87E4F);
    P(D, A, B, C, 15, 10, 0xFE2CE6E0);
    P(C, D, A, B,  6, 15, 0xA3014314);
    P(B, C, D, A, 13, 21, 0x4E0811A1);
    P(A, B, C, D,  4,  6, 0xF7537E82);
    P(D, A, B, C, 11, 10, 0xBD3AF235);
    P(C, D, A, B,  2, 15, 0x2AD7D2BB);
    P(B, C, D, A,  9, 21, 0xEB86D391);

#undef F

    ctx->state[0] += A;
    ctx->state[1] += B;
    ctx->state[2] += C;
    ctx->state[3] += D;
}

/*
 * MD5 process buffer
 */
__device__ void md5_update(md5_context *ctx, const unsigned char *input, size_t ilen)
{
    size_t fill;
    uint32_t left;

    if (ilen == 0)
        return;

    left = ctx->total[0] & 0x3F;
    fill = 64 - left;

    ctx->total[0] += (uint32_t) ilen;
    ctx->total[0] &= 0xFFFFFFFF;

    if (ctx->total[0] < (uint32_t) ilen)
        ctx->total[1]++;

    if (left && ilen >= fill)
    {
        memcpy((void *) (ctx->buffer + left), input, fill);
        md5_process(ctx, ctx->buffer);
        input += fill;
        ilen  -= fill;
        left = 0;
    }

    while(ilen >= 64)
    {
        md5_process(ctx, input);
        input += 64;
        ilen  -= 64;
    }

    if (ilen > 0)
    {
        memcpy((void *) (ctx->buffer + left), input, ilen);
    }
}

__constant__ static const unsigned char md5_padding[64] =
{
 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

/*
 * MD5 final digest
 */
__device__ void md5_finish(md5_context *ctx, unsigned char output[16])
{
    uint32_t last, padn;
    uint32_t high, low;
    unsigned char msglen[8];

    high = (ctx->total[0] >> 29)
         | (ctx->total[1] <<  3);
    low  = (ctx->total[0] <<  3);

    PUT_UINT32_LE(low,  msglen, 0);
    PUT_UINT32_LE(high, msglen, 4);

    last = ctx->total[0] & 0x3F;
    padn = (last < 56) ? (56 - last) : (120 - last);

    md5_update(ctx, md5_padding, padn);
    md5_update(ctx, msglen, 8);

    PUT_UINT32_LE(ctx->state[0], output,  0);
    PUT_UINT32_LE(ctx->state[1], output,  4);
    PUT_UINT32_LE(ctx->state[2], output,  8);
    PUT_UINT32_LE(ctx->state[3], output, 12);
}

/*
 * output = MD5(input buffer)
 */
__device__ void md5(const unsigned char *input, size_t ilen, unsigned char output[16])
{
    md5_context ctx;

    md5_init(&ctx);
    md5_starts(&ctx);
    md5_update(&ctx, input, ilen);
    md5_finish(&ctx, output);
    md5_free(&ctx);
}

// ***************************** END OF LIBRARY ******************************************

__device__ 
int check_md5_match(const unsigned char * word, size_t * len, unsigned char * target_md5) 
{
	unsigned char word_md5[16];
	md5(word, *len, word_md5);

	int hash_match = 1;
	for(int i = 0; i < 16; i++){
		if(word_md5[i] != target_md5[i]){
			hash_match = 0;
			continue;
		}
	}
	return hash_match;
}
 
__global__ 
void batch_hash_check(Wordlist * words, int * word_counter) 
{
    int threadId = threadIdx.x + blockIdx.x * blockDim.x ;
    if (threadId < *word_counter-1){
        size_t len = words->indicies[threadId+1] - words->indicies[threadId] * sizeof(char);
        words->results[threadId] = check_md5_match((const unsigned char *) &words->characters[words->indicies[threadId]], &len, d_target_hash);
    }
}

static void usage(){    
    printf("Usage: ./hashcrack -w <wordlist file path> -l <hashlist file path> [-h]\n");
}

// Parse the command line arguments using getopt and return an Argument structure
// GetOpt requies the POSIX C Library
static Arguments parse_arguments(const int argc, char ** argv){   
    // Argument format string for getopt
    static const char * _ARG_STR = "hw:l:";
    // Initialize arguments to their default values    
    Arguments args;
    // Parse any command line options
    int c;
    while ((c = getopt(argc, argv, _ARG_STR)) != -1) {
        switch (c) {
            case 'w':
                args.word_list = optarg;
                break;
            case 'l':
                args.hash_list = optarg;
				break;
			// case 's': //salt
            //     args.hash_list = optarg;
            //     break;
            case 'h':
                // 'help': print usage, then exit
                // note the fall through
                usage();
            default:
                exit(-1);
        }
    }
    return args;
}

char * get_word(Wordlist * words, int i) {
    size_t len1 = (words->indicies[i+1]-words->indicies[i] + 1) * sizeof(char);
    size_t len = (words->indicies[i+1]-words->indicies[i]) * sizeof(char);
    char * ith_word;
    ith_word = (char*) malloc (len1);
    strncpy(ith_word, &words->characters[words->indicies[i]], len);
    return  ith_word;
}

// The folowing two functions were retrevied from the link below
// https://stackoverflow.com/questions/17261798/converting-a-hex-string-to-a-byte-array
int char2int(char input)
{
  if(input >= '0' && input <= '9')
    return input - '0';
  if(input >= 'A' && input <= 'F')
    return input - 'A' + 10;
  if(input >= 'a' && input <= 'f')
    return input - 'a' + 10;
  throw std::invalid_argument("Invalid input string");
}

// This function assumes src to be a zero terminated sanitized string with
// an even number of [0-9a-f] characters, and target to be sufficiently large
void hex2bin(const char* src, unsigned char* target)
{
  while(*src && src[1])
  {
    *(target++) = char2int(*src)*16 + char2int(src[1]);
    src += 2;
  }
}

void process_hash(Arguments args)
{
    std::ifstream word_file(args.word_list);
    assert(word_file.is_open());

    std::string word;
    Wordlist words;
    int word_counter = 0;
    int char_counter = 0;

    while (word_file >> word && char_counter < MAX_CHARS)
    {
        //printf("Word # %d:  %s\n", word_counter, word);
        words.indicies[word_counter++] = char_counter;

        memcpy(&words.characters[char_counter], word.c_str(), word.length() * sizeof(char) );

        char_counter += word.length();
    }
    int * d_word_counter;

    cudaMalloc((void**) &d_word_counter, sizeof(int));
    cudaMemcpy(d_word_counter, &word_counter, sizeof(int), cudaMemcpyHostToDevice);

    printf("Number of words proccsed for kernal execution:  %d\n", word_counter);
    //words.count = word_counter;
    Wordlist *words_d;
 
	cudaMalloc( (void**)&words_d, sizeof(Wordlist) ); 
	cudaMemcpy( words_d, &words, sizeof(Wordlist), cudaMemcpyHostToDevice );
    
    int blockSize;   // The launch configurator returned block size 
    int minGridSize; // The minimum grid size needed to achieve the 
                     // maximum occupancy for a full device launch 
    int gridSize;    // The actual grid size needed, based on input size 
  
    cudaOccupancyMaxPotentialBlockSize( &minGridSize, &blockSize, 
                                        batch_hash_check, 0, 0); 
    // Round up according to array size 
    gridSize = (word_counter + blockSize - 1) / blockSize; 
    
    //printf("G B:  %d %d\n", gridSize, blockSize);
    batch_hash_check<<<gridSize, blockSize>>>(words_d, d_word_counter);

    cudaDeviceSynchronize();

    cudaError_t e=cudaGetLastError();
    if(e!=cudaSuccess) {
        printf("Cuda failure %s:%d: '%s'\n",__FILE__,__LINE__,cudaGetErrorString(e));
        exit(0);
    }

    int results[MAX_CHARS];
    cudaMemcpy(results, words_d->results, MAX_CHARS * sizeof (int), cudaMemcpyDeviceToHost ); 
    cudaFree( words_d );

    for(int i=0; i < word_counter; i++){
        if (results[i] == 1 ){
            char * buffer;
            buffer = get_word(&words,i);
            printf("Match found! The password is:  %s , Length %zu\n", buffer, strlen(buffer));
            free(buffer);
        }
    }
}
 
int main(int argc, char ** argv)
{
	Arguments args = parse_arguments(argc, argv);
	
    std::ifstream hash_file(args.hash_list);

    assert(hash_file.is_open());
    
    std::string pw_hash;

    // create events for timing
    cudaEvent_t startEvent, stopEvent; 
    cudaEventCreate(&startEvent);
    cudaEventCreate(&stopEvent);
    float time;

    
    
	while (hash_file >> pw_hash)
	{
        cudaEventRecord(startEvent, 0);

        printf("\nCraking hash:  %s\n", pw_hash.c_str());
        hex2bin(pw_hash.c_str(),h_target_hash);
        cudaMemcpyToSymbol(d_target_hash, h_target_hash, HASH_LEN_CHAR * sizeof(unsigned char));
        process_hash(args);

        cudaEventRecord(stopEvent, 0);
        cudaEventSynchronize(stopEvent);
        cudaEventElapsedTime(&time, startEvent, stopEvent);
        printf("Cracking this hash took %f ms\n", time);
    }

   
	return EXIT_SUCCESS;
}