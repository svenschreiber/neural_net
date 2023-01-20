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
    test_images,  _c := read_file("res/datasets/mnist/t10k-images.idx3-ubyte");
    test_labels,  _d := read_file("res/datasets/mnist/t10k-labels.idx1-ubyte");

    result: MNIST_Dataset;
    result.x_train, result.y_train = mnist_fill_data(xx train_images.data, xx train_labels.data, MNIST_TRAIN_SIZE);
    result.x_test, result.y_test = mnist_fill_data(xx test_images.data, xx test_labels.data, MNIST_TEST_SIZE);
    return result;
}

mnist_fill_data :: (x_data: *u8, y_data: *u8, size: u64) -> []f32, []f32 {
    imgs := allocate_array(MNIST_IMG_BYTES * size, f32);
    labels := allocate_array(size, f32);
    for i := 0; i < size; ++i {
        for j := 0; j < MNIST_IMG_BYTES; ++j {
            imgs[i * MNIST_IMG_BYTES + j] = xx x_data[i * MNIST_IMG_BYTES + j + MNIST_IMG_INFO_LEN] / 255.0;
        }
        labels[i] = xx y_data[i + MNIST_LABEL_INFO_LEN];
    }
    return imgs, labels;
}

mnist_get_image :: (idx: u64, x_data: []f32) -> *f32 {
    return *x_data[idx * MNIST_IMG_BYTES];
}

mnist_get_label :: (idx: u64, y_data: []f32) -> f32 {
    return y_data[idx];
}