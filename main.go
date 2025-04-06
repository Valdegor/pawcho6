package main

import (
    "fmt"
    "net"
    "net/http"
    "os"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        ip := getLocalIP()
        hostname, _ := os.Hostname()
        version := os.Getenv("APP_VERSION")

        fmt.Fprintf(w, "<h1>Wersja: %s</h1><p>Host: %s</p><p>IP: %s</p>", version, hostname, ip)
    })

    http.ListenAndServe(":8080", nil)
}

func getLocalIP() string {
    addrs, err := net.InterfaceAddrs()
    if err != nil {
        return "unknown"
    }

    for _, addr := range addrs {
        if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() && ipnet.IP.To4() != nil {
            return ipnet.IP.String()
        }
    }

    return "unknown"
}
