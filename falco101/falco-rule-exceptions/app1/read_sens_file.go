package main

import (
	"io/ioutil"
	"os"
    "fmt"
    "time"
)

// https://github.com/falcosecurity/event-generator/blob/b8ed1a9420ff46926b5bf936832f1af1f799cd5c/events/syscall/read_sensitive_file_untrusted.go
func main() {

    counter := 0
    for {
        const filename = "/etc/shadow"
        fmt.Println("%d - Sleeping 1 second and reading sensitive file: %s", counter, filename)
        time.Sleep(time.Second)
        file, _ := os.Open(filename)
        defer file.Close()
        counter = counter + 1
    }
}

