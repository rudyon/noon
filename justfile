build:
    @mkdir -p bin
    @crystal build src/noonc.cr -o bin/noonc --progress

clean:
    @rm -f bin/*

format:
    @crystal tool format
