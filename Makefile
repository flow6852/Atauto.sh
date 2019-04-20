TARGET=Atauto.sh
SUBCMD=get_testcase
SUBC=$(SUBCMD).c
INSDIR=$(HOME)/.local/bin

install:
	mkdir -p ../AtCoder ../AtCoder/input ../AtCoder/output $(HOME)/.config/Atauto
	cp src/$(TARGET) $(INSDIR)/$(TARGET)
	cp confs/* $(HOME)/.config/Atauto
	gcc -Wall -o $(SUBCMD) src/$(SUBC)
	mv $(SUBCMD) $(INSDIR)
	@read -p "username ? " Username ; read -p "password ? " -s Password ; echo -e "$${Username}\n$${Password}" > $(HOME)/.config/Atauto/.user.conf
	@echo -e "\n...installed"

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
