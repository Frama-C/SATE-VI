// RAND* macros
#define URAND31() (((unsigned)(rand()%2)<<30) ^ ((unsigned)rand()<<15) ^ rand())
// choose to produce a positive or a negative number. Note: conditional only evaluates one URAND31
#define RAND32() (rand() & 1 ? (int)URAND31() : -(int)URAND31() - 1)

/* rand only returns 15 bits, so we xor 5 calls together to get the full result (11 bits overflow, but that is okay) */
// shifting signed values might overflow and be undefined
#define URAND63() (((uint64_t)(rand()%8)<<60) ^ ((uint64_t)rand()<<45) ^ ((uint64_t)rand()<<30) ^ ((uint64_t)rand()<<15) ^ rand())
// choose to produce a positive or a negative number. Note: conditional only evaluates one URAND63
#define RAND64() (rand() & 1 ? (int64_t)URAND63() : -(int64_t)URAND63() - 1)

// Extra definitions to avoid downcasts in some tests
#define URAND15() (rand() % (1<<15))
#define RAND16() (rand() & 1 ? (short)URAND15() : -((short)URAND15()) - 1)

#define URAND7() (rand() % (1<<7))
#define RAND8() (rand() & 1 ? (char)URAND7() : -((char)URAND7()) - 1)
