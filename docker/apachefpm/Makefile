all:; date

build:; docker build -t debian9fpm ./ --build-arg "cedric:$(cmdp show epiconcept/apt|head -1)"

test:; docker run -ti -d --name debian9fpm_test 