#!/bin/bash

rm -rf docs/

swift build --target CSUSTKit \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc .build

xcrun docc convert CSUSTKit.docc \
    --additional-symbol-graph-dir .build \
    --output-path ./docs \
    --transform-for-static-hosting
