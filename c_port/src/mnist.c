typedef struct MNIST_Dataset MNIST_Dataset;
struct MNIST_Dataset {
    f32 *x_train;
    f32 *y_train;
    f32 *x_test;
    f32 *y_test;
};

#define MNIST_TRAIN_SIZE 60000
#define MNIST_TEST_SIZE 10000
#define MNIST_IMG_SIZE 28
#define MNIST_IMG_BYTES MNIST_IMG_SIZE * MNIST_IMG_SIZE
#define MNIST_IMG_INFO_LEN 16
#define MNIST_LABEL_INFO_LEN 8

MNIST_Dataset load_mnist() {
    Platform_File train_images, train_labels, test_images, test_labels;
    platform_read_entire_file("../res/datasets/mnist/train-images.idx3-ubyte", &train_images);
    platform_read_entire_file("../res/datasets/mnist/train-labels.idx1-ubyte", &train_labels);
    platform_read_entire_file("../res/datasets/mnist/t10k-images.idx3-ubyte", &test_images);
    platform_read_entire_file("../res/datasets/mnist/t10k-labels.idx1-ubyte", &test_labels);

    MNIST_Dataset result;
    result.x_train = (f32 *)malloc(MNIST_IMG_BYTES * MNIST_TRAIN_SIZE * sizeof(f32));
    result.y_train = (f32 *)malloc(MNIST_TRAIN_SIZE * sizeof(f32));
    for (u32 i = 0; i < MNIST_TRAIN_SIZE; ++i) {
        for (u32 j = 0; j < MNIST_IMG_BYTES; ++j) {
            result.x_train[i * MNIST_IMG_BYTES + j] = (f32)(train_images.data[i * MNIST_IMG_BYTES + j + MNIST_IMG_INFO_LEN]) / 255.0f;
        }
        result.y_train[i] = (f32) train_labels.data[i + MNIST_LABEL_INFO_LEN];
    }

    result.x_test = (f32 *)malloc(MNIST_IMG_BYTES * MNIST_TEST_SIZE * sizeof(f32));
    result.y_test = (f32 *)malloc(MNIST_TEST_SIZE * sizeof(f32));
    for (u32 i = 0; i < MNIST_TEST_SIZE; ++i) {
        for (u32 j = 0; j < MNIST_IMG_BYTES; ++j) {
            result.x_test[i * MNIST_IMG_BYTES + j] = (f32)(test_images.data[i * MNIST_IMG_BYTES + j + MNIST_IMG_INFO_LEN]) / 255.0f;
        }
        result.y_test[i] = (f32) test_labels.data[i + MNIST_LABEL_INFO_LEN];
    }

    return result;
}