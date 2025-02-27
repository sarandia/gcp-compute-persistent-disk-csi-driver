# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.13.15 as builder
WORKDIR /go/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver
ADD . .
RUN make

# MAD HACKS: Build a version first so we can take the scsi_id bin and put it somewhere else in our real build
FROM k8s.gcr.io/build-image/debian-base-amd64:v2.1.3 as base
RUN clean-install udev

# Start from Kubernetes Debian base
FROM k8s.gcr.io/build-image/debian-base-amd64:v2.1.3
COPY --from=builder /go/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver/bin/gce-pd-csi-driver /gce-pd-csi-driver
# Install necessary dependencies
RUN clean-install util-linux e2fsprogs mount ca-certificates udev xfsprogs
COPY --from=base /lib/udev/scsi_id /lib/udev_containerized/scsi_id

ENTRYPOINT ["/gce-pd-csi-driver"]
