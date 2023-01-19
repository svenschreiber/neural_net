MNIST_Dataset :: struct {
    x_train: []f32;
    y_train: []f32;
    x_test: []f32;
    y_test: []f32;
}

MNIST_TRAIN_SIZE :: 60000;
MNIST_TEST_SIZE  :: 10000;
MNIST_IMG_SIZE   :: 28;
MNIST_IMG_BYTES  :: 784;
MNIST_IMG_INFO_LEN   :: 16;
MNIST_LABEL_INFO_LEN :: 8;

load_mnist :: () -> MNIST_Dataset {
    train_images, _a := read_file("res/datasets/mnist/train-images.idx3-ubyte");
    train_labels, _b := read_file("res/datasets/mnist/train-labels.idx1-ubyte");
    test_images, _c  := read_file("res/datasets/mnist/t10k-images.idx3-ubyte");
    test_labels, _d  := read_file("res/datasets/mnist/t10k-labels.idx1-ubyte");

    result: MNIST_Dataset;

    result.x_train = allocate_array(MNIST_IMG_BYTES * MNIST_TRAIN_SIZE, f32);
    result.y_train = allocate_array(MNIST_TRAIN_SIZE, f32);
    for i := 0; i < MNIST_TRAIN_SIZE; ++i {
        for j := 0; j < MNIST_IMG_BYTES; ++j {
            result.x_train[i * MNIST_IMG_BYTES + j] = cast(f32)(cast(u8)train_images.data[i * MNIST_IMG_BYTES + j + MNIST_IMG_INFO_LEN]) / 255.0;
        }
        result.y_train[i] = xx train_labels.data[i + MNIST_LABEL_INFO_LEN];
    }

    result.x_test  = allocate_array(MNIST_IMG_BYTES * MNIST_TEST_SIZE, f32);
    result.y_test  = allocate_array(MNIST_TEST_SIZE, f32);
    for i := 0; i < MNIST_TEST_SIZE; ++i {
        for j := 0; j < MNIST_IMG_BYTES; ++j {
            result.x_test[i * MNIST_IMG_BYTES + j] = cast(f32)(cast(u8)test_images.data[i * MNIST_IMG_BYTES + j + MNIST_IMG_INFO_LEN]) / 255.0;
        }
        result.y_test[i] = xx test_labels.data[i + MNIST_LABEL_INFO_LEN];
    }

    return result;
}