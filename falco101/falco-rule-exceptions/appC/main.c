#include <stdlib.h>
#include <unistd.h>

int main() {
    while (1 < 3){
        system("/bin/bash");
        sleep(1);
    }
    return 0;
}