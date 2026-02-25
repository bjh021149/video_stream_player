# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-src"
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-build"
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix"
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix/tmp"
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix/src/objectbox-download-populate-stamp"
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix/src"
  "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix/src/objectbox-download-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix/src/objectbox-download-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/linyu/aiCoder/video_stream_player/build/linux/x64/debug/_deps/objectbox-download-subbuild/objectbox-download-populate-prefix/src/objectbox-download-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
