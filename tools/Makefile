CC = xcrun -sdk iphoneos clang -arch arm64
TOOLS_SRC = $(wildcard *.c)
TOOLS = $(TOOLS_SRC:.c=)

all: $(TOOLS)

%: %.c
	@echo "CC $@"
	@$(CC) -o $@ $<

clean:
	rm -f $(TOOLS)
