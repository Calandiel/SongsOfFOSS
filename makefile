BASE_RELEASE_DIR = release
RELEASE_DIR_UNIX = $(BASE_RELEASE_DIR)/linux-and-mac
RELEASE_DIR_WIN = $(BASE_RELEASE_DIR)/windows
LOVE_WIN_DIR = love-windows
ASSETS_DIR = sote

.PHONY: all

all: sote launch_sote

launch_sote:
	@echo "Generating launch_sote command..."
	@echo "#!/bin/bash" > launch_sote
	@echo "love $(RELEASE_DIR_UNIX)/sote.love" >> launch_sote
	@chmod u+x launch_sote
	@echo "If you are on Windows, your .exe file is in $(RELEASE_DIR_WIN)/sote.exe"


sote: $(RELEASE_DIR_UNIX)/sote.love $(RELEASE_DIR_WIN)/sote.exe
	@echo "Done!"

install:
	@echo "Installing SOTE to ~/.local/bin..."
	@install -m 755 launch_sote ~/.local/bin/launch_sote
	@mkdir -p ~/.local/bin/$(RELEASE_DIR_UNIX)
	@install -m 755 $(RELEASE_DIR_UNIX)/sote.love ~/.local/bin/$(RELEASE_DIR_UNIX)/sote.love

uninstall:
	@echo "Uninstalling SOTE from ~/.local/bin..."
	@rm -f ~/.local/bin/launch_sote
	@rm -f ~/.local/bin/$(RELEASE_DIR_UNIX)/sote.love

.PHONY: clean

clean:
	@echo "Cleaning artifacts..."
	@echo "Removing ./$(BASE_RELEASE_DIR)..."
	@rm -rf $(BASE_RELEASE_DIR)
	@echo "Removing ./launch_sote..."
	@rm -f launch_sote
	@echo "Removing ./$(LOVE_WIN_DIR)..."
	@rm -rf $(LOVE_WIN_DIR)


$(RELEASE_DIR_UNIX)/sote.love: RELEASE_DIR_UNIX
	@echo "Creating .love archive..."
	@cd $(ASSETS_DIR) && zip -9 -r sote.love .
	@cd ..
	@cp $(ASSETS_DIR)/sote.love $(RELEASE_DIR_UNIX)/sote.love
	@rm -f $(ASSETS_DIR)/sote.love

$(RELEASE_DIR_WIN)/sote.exe: RELEASE_DIR_WIN $(RELEASE_DIR_UNIX)/sote.love $(LOVE_WIN_DIR)/love.exe
	@echo "Creating .exe file..."
	@cat $(LOVE_WIN_DIR)/love.exe $(RELEASE_DIR_UNIX)/sote.love > $(RELEASE_DIR_WIN)/sote.exe
	@cp $(LOVE_WIN_DIR)/ $(RELEASE_DIR_WIN)/ -r -u -T
	@rm -f $(RELEASE_DIR_WIN)/love.exe

$(LOVE_WIN_DIR)/love.exe: RELEASE_DIR_WIN LOVE_WIN_DIR
	@echo "Copying love.exe to $(LOVE_WIN_DIR)/love.exe..."
	@cp $(shell which love) $(LOVE_WIN_DIR)/love.exe -u -T

RELEASE_DIR_UNIX:
	@echo "Creating release directory $(RELEASE_DIR_UNIX)..."
	@mkdir -p $(RELEASE_DIR_UNIX)

RELEASE_DIR_WIN:
	@echo "Creating release directory $(RELEASE_DIR_WIN)..."
	@mkdir -p $(RELEASE_DIR_WIN)

LOVE_WIN_DIR:
	@echo "Creating love-windows directory $(LOVE_WIN_DIR)..."
	@mkdir -p $(LOVE_WIN_DIR)