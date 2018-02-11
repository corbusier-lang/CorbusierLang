#!/usr/bin/bash

rm -f Sources/CorbusierLang/stdlib.swift

touch Sources/CorbusierLang/stdlib.swift
echo $'internal let stdlib = """' >> Sources/CorbusierLang/stdlib.swift
cat stdlib/stdlib.sier >> Sources/CorbusierLang/stdlib.swift
echo $'"""' >> Sources/CorbusierLang/stdlib.swift
