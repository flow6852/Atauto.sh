TARGET=Atauto.sh
SUBCMD=get_testcase
SUBC=$(SUBCMD).c
INSDIR=$(HOME)/.local/bin

install:
	mkdir -p $(HOME)/.config/Atauto
	cp src/$(TARGET) $(INSDIR)/$(TARGET)
	cp confs/* $(HOME)/.config/Atauto
	gcc -Wall -o $(SUBCMD) src/$(SUBC)
	mv $(SUBCMD) $(INSDIR)
	@echo -e "...installed"

reinstall:
	cp src/$(TARGET) $(INSDIR)/$(TARGET)
	cp confs/* $(HOME)/.config/Atauto
	gcc -Wall -o $(SUBCMD) src/$(SUBC)
	mv $(SUBCMD) $(INSDIR)
	@echo "...reinstalled"
	
uninstall:
	rm $(INSDIR)/$(SUBCMD) $(INSDIR)/$(TARGET)
	rm -rf $(HOME)/.config/Atauto
	@echo "...uninstalled"
