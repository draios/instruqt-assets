#include <stdio.h>
#include <stdlib.h>


int main() {
    FILE *f = popen("bash ls; pwd; ls", "r");
    char line[1024];
    // size_t len;
    while (fgets(line, 1024, f) != NULL) {
        printf("%s", line);
    }
    pclose(f);
    return 0;
}