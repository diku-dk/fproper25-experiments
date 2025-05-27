#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

void generate_word(int i, int min_len, int max_len) {
  int len = min_len + rand() % (max_len - min_len + 1) - printf("%d", i);
  for (int i = 0; i < len; i++) {
    putchar('a' + rand() % 26);
  }
  putchar('\n');
}

int main(int argc, char *argv[]) {
  assert(argc == 4);

  int num_words = atoi(argv[1]);
  int min_len = atoi(argv[2]);
  int max_len = atoi(argv[3]);

  srand(num_words ^ min_len ^ max_len);

  for (int i = 0; i < num_words; i++) {
    generate_word(i, min_len, max_len);
  }

  return 0;
}
