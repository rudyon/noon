build:
    @mkdir -p bin
    @crystal build src/noon.cr -o bin/noon --progress

clean:
    @rm -f bin/*

format:
    @crystal tool format
