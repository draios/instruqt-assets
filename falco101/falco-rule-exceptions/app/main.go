package main

import (
    // "fmt"
    // "html"
    // "log"
    // "net/http"
	"io/ioutil"
	"os"
    "fmt"
    "time"
)

func main() {

    // http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    //     fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
    // })

    // http.HandleFunc("/hi", func(w http.ResponseWriter, r *http.Request){
    //     fmt.Fprintf(w, "Hi")
    // })

    // log.Fatal(http.ListenAndServe(":8081", nil))
    for {
		const filename = "/etc/binary"
        fmt.Println("Writing to %s", filename)
		defer os.Remove(filename)
		return ioutil.WriteFile(filename, nil, os.FileMode(0755))	
        time.Sleep(time.Second)
    }

}


// https://github.com/falcosecurity/event-generator/blob/b8ed1a9420ff46926b5bf936832f1af1f799cd5c/events/syscall/write_below_etc.go