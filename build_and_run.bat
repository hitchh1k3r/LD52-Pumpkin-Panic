@echo off


pushd build

  :: -vet -warnings-as-errors -strict-style

  :: -o:speed

  odin run ../src/ -ignore-unknown-attributes ^
                    -o:speed -subsystem:windows
                    :: -o:speed
                    :: -o:minimal -debug

popd
