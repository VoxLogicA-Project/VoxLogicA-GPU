#!/bin/bash


for m in cpu gpu; do
fmla=x
rm -rf in-$m.imgql out-$m
cat << EOF >> in-$m.imgql
load img="flair.nii.gz"
let x=intensity(img) >. 100

save "out-$m/x.nii.gz" x
EOF

for i in $(seq 1 10); do

cat << EOF >> in-$m.imgql
save "out-$m/$i.nii.gz" $fmla
EOF
fmla="N $fmla"

done

done

/home/VoxLogicA/binaries/VoxLogicA_0.6.4.3-experimental_linux-x64/VoxLogicA in-cpu.imgql
../src/bin/release/net5.0/linux-x64/VoxLogicA in-gpu.imgql

diff -qr out-{cpu,gpu}
echo diff: $?