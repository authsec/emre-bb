ARG EMACS_VERSION="28.2"

FROM authsec/sphinx
LABEL maintainer="Jens Frey <jens.frey@coffeecrew.org>" Version="2022-12-02"

ARG EMACS_VERSION
ENV EMACS_VERSION=$EMACS_VERSION

WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive
# Install build dependencies (can also be used to build with gtk3 instead of the [here preferred] lucid toolkit)
RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install \
        curl \
        checkinstall \
        coreutils \
        git \
        texinfo \
        install-info \
        build-essential \
        libjansson-dev \
        libgtk-3-dev \
        libtiff5-dev \
        libgif-dev \
        libjpeg-dev \
        libpng-dev \
        libxpm-dev \
        libncurses-dev \
        libwebkit2gtk-4.0-dev \
        libgnutls28-dev \
        libgccjit-12-dev\
        zlib1g-dev \
        libmagick++-6.q16-dev \
        gcc-12 \
        g++-12 \
        autoconf \
        libxi-dev \
        libxft-dev \
        libxaw7-dev \
        librsvg2-dev \
        ruby-dev

WORKDIR /tmp

# Download emacs 
RUN curl "https://ftp.gnu.org/pub/gnu/emacs/emacs-${EMACS_VERSION}.tar.gz" | tar xz && mv emacs* emacs

# Can Get 29 from source
# RUN git clone --depth 1 git://git.savannah.gnu.org/emacs.git

WORKDIR /tmp/emacs

# Create emacs installer and make sure to use x-toolkit lucid, as gtk3 will give
# weird rendering artifacts in conjunction with a remote X11 display like XQuartz 
# on Mac
ENV CC="gcc-12"
RUN ./autogen.sh && \
    ./configure \
        --prefix=/home/emre/local \
        --with-modules \
        --with-file-notification=inotify \
        --with-imagemagick \
        --with-mailutils \
        --with-harfbuzz \
        --with-json \
        --with-x=yes \
        --with-wide-int \
        --with-xft \
        --with-xml2 \
        --with-x-toolkit=lucid \
        --with-lcms2 \
        --with-cairo \
        --with-xpm=yes \
        --with-gif=yes \
        --with-gnutls=yes \
        --with-jpeg=yes \
        --with-png=yes \
        --with-tiff=yes \
        --with-rsvg \
        --without-compress-install \
        --with-native-compilation \
        --with-modules \
        --with-xinput2 \
        CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security" \
        CPPFLAGS="-Wdate-time -D_FORTIFY_SOURCE=2" LDFLAGS="-Wl,-Bsymbolic-functions -Wl,-z,relro" && \
    make NATIVE_FULL_AOT=1 -j$(nproc) && \
    make install-strip && \
    checkinstall --install=yes --default --pkgname=emacs --pkgversion="${EMACS_VERSION}" && \
    cp emacs*.deb /emacs.deb

# Get the citation-style-language styles, so we can use them with the new org-mode
RUN git clone --depth 1 https://github.com/citation-style-language/styles /tmp/csl/styles && \
    git clone --depth 1 https://github.com/citation-style-language/locales /tmp/csl/locales

# Clone authsec styles into the image
RUN git clone --depth 1 https://github.com/authsec/latex-styles.git /tmp/latex-styles

# Clone all the icons into font directory, so they do not have to be downloaded
RUN git clone --depth 1 https://github.com/domtronn/all-the-icons.el.git /tmp/all-the-icons

# Install nerd fonts
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
