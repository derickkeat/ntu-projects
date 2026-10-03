from knn import KNN, load_data, load_labels


def main():
    train_data, train_fields = load_data("train.csv")
    train_labels = load_labels("train_gt.csv")

    val_data, val_fields = load_data("val.csv")
    val_labels = load_labels("val_gt.csv")

    best_k = 0
    best_correct = 0

    for k in range(50):
        print("Case " + str(k))
        knn = KNN(k)
        preprocessed_train = knn.preprocess_data(train_data, train_fields)
        preprocessed_val = knn.preprocess_data(val_data, val_fields)

        normalized_train = knn.normalize_data(preprocessed_train)
        normalized_val = knn.normalize_data(preprocessed_val)

        knn.fit(normalized_train, train_labels)
        predictions = knn.predict(normalized_val)

        correct = knn.validate(predictions, val_labels)

        if correct > best_correct:
            best_correct = correct
            best_k = k

    print(best_correct)
    print(best_k)


if __name__ == "__main__":
    main()
