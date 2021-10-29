package etc-writer

import (
	"io/ioutil"
	"os"
    "fmt"
    "time"
)

func main() {

    // https://github.com/falcosecurity/event-generator/blob/b8ed1a9420ff46926b5bf936832f1af1f799cd5c/events/syscall/write_below_etc.go
    for {
        time.Sleep(time.Second)
        const filename = "/etc/binary"
        fmt.Println("Writing to %s", filename)
        defer os.Remove(filename)
        ioutil.WriteFile(filename, nil, os.FileMode(0755))
    }
}

