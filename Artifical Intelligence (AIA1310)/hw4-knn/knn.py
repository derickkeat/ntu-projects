import csv
import math

class KNN:
    def __init__(self, k=5):
        self.k = k
        self.train_data = []
        self.train_labels = []

    def preprocess_data(self, data: dict, fields: list):
        """Convert categorical and numerical data into binary number."""

        fields = fields[1:]  # NOTE: exclude the first field (gender)
        
        # Binary Features Dictionary
        binary_features = {
            "gender": {"Male": 0, "Female": 1},
            "SeniorCitizen": {"No": 0, "Yes": 1},
            "Partner": {"No": 0, "Yes": 1},
            "Dependents": {"No": 0, "Yes": 1},
            "PhoneService": {"No": 0, "Yes": 1},
            "PaperlessBilling": {"No": 0, "Yes": 1}
        }

        # Multi-Features Dictionary
        multi_features = {
            "MultipleLines": {"No": 0, "Yes": 1, "No phone service": 2},
            "InternetService": {"No": 0, "DSL": 1, "Fiber optic": 2},
            "OnlineSecurity": {"No": 0, "Yes": 1, "No internet service": 2},
            "OnlineBackup": {"No": 0, "Yes": 1, "No internet service": 2},
            "DeviceProtection": {"No": 0, "Yes": 1, "No internet service": 2},
            "TechSupport": {"No": 0, "Yes": 1, "No internet service": 2},
            "StreamingTV": {"No": 0, "Yes": 1, "No internet service": 2},
            "StreamingMovies": {"No": 0, "Yes": 1, "No internet service": 2},
            "Contract": {"Month-to-month": 0, "One year": 1, "Two year": 2},
            "PaymentMethod": {
                "Electronic check": 0, 
                "Mailed check": 1, 
                "Bank transfer (automatic)": 2, 
                "Credit card (automatic)": 3
            }
        }

        processed = []

        for row in data:
            processed_row = []
            for key in fields:
                value = row[key]

                if key in binary_features:
                    processed_row.append(binary_features[key][value])
                elif key in multi_features:
                    processed_row.append(multi_features[key][value])
                else:
                    processed_row.append(float(value))

            processed.append(processed_row)
        
        return processed

    def normalize_data(self, data: list[list]):
        """Normalize the data to a scale of 0 - 1."""
        
        # min/max value for each column
        min_val = [float("inf") for _ in range(len(data[0]))]
        max_val = [float("-inf") for _ in range(len(data[0]))]

        # find the min and max value for each column
        for row in data:
            for i, val in enumerate(row):
                min_val[i] = min(min_val[i], float(val))
                max_val[i] = max(max_val[i], float(val))

        # print(max_val)
        # print(min_val)

        normalized = []

        for row in data:
            normalized_row = []
            for i, val in enumerate(row):
                if i == 3 or i == 16 or i == 17:
                    normalized_val = (val - min_val[i]) / (max_val[i] - min_val[i])
                    normalized_row.append(normalized_val)
                else:
                    normalized_row.append(val)

            normalized.append(normalized_row)
        # print(normalized)
        return normalized

    def euclidean_distance(self, row1, row2):
        """Calculate the euclidean distance between two points."""
        distance = 0.0
        for i in range(len(row1)):
            # if i == 0: # NOTE: excluded gender
            #     continue
            distance += (row1[i] - row2[i]) ** 2

        return math.sqrt(distance)

    def fit(self, train_data, train_labels):
        self.train_data = train_data
        self.train_labels = train_labels

    def predict(self, test_data: list) -> list:
        """Predict labels of test data."""
        predictions = []

        for test_row in test_data:
            distances = []
            for i, train_row in enumerate(self.train_data):
                # if i == 0:  # NOTE: excluded gender
                #     continue
                dist = self.euclidean_distance(test_row, train_row)
                distances.append((dist, self.train_labels[i]))

            distances.sort(key = lambda x: x[0])
            neighbors = distances[:self.k]

            # print(neighbors)

            votes = {"Yes": 0, "No": 0}

            for _, label in neighbors:
                votes[label] += 1
                
            prediction = max(votes, key=votes.get)
            predictions.append(prediction)

        return predictions

    def validate(self, predictions: list, labels: list):
        correct = 0
        total = 0
        for i in range(len(predictions)):
            if predictions[i] == labels[i]:
                correct += 1
            total += 1

        print("total: " + str(total))
        print("correct: " + str(correct))
        print("percentage: " + str(correct / total))

        return correct

def load_data(data_file) -> tuple[dict, list]:
    """Load the data into a dictionary with key:value as label:data."""
    data = []
    with open(data_file) as train_data:
        csv_reader = csv.DictReader(train_data)

        for row in csv_reader:
            data.append(row)

    with open(data_file) as train_data:
        csv_reader = csv.reader(train_data)

        fields = next(csv_reader)

    return data, fields

def load_labels(label_file) -> list:
    """Load the labels into a list."""
    labels = []
    with open(label_file) as label_data:
        csv_reader = csv.DictReader(label_data)

        for row in csv_reader:
            labels.append(row["Churn"])

    return labels

def save_predictions(filename, predictions):
    """Save the predictions to a csv."""
    with open(filename, mode="w", newline="") as prediction_file:
        prediction_writer = csv.writer(prediction_file)
        prediction_writer.writerow(["Churn"])
        for prediction in predictions:
            prediction_writer.writerow([prediction]) 

def main():
    train_data, train_fields = load_data("train.csv")
    train_labels = load_labels("train_gt.csv")

    # print(train_data[0])
    # print(train_fields[0])
    # print(train_labels[0])

    val_data, val_fields = load_data("val.csv")
    test_data, test_fields = load_data("test.csv")

    # print(test_data[0])
    # print(test_fields[0])
    # print(test_labels[0])

    knn = KNN(40)
    preprocessed_train_data = knn.preprocess_data(train_data, train_fields)
    preprocessed_val_data = knn.preprocess_data(val_data, val_fields)
    preprocessed_test_data = knn.preprocess_data(test_data, test_fields)

    # print(preprocessed_train_data[0])
    # print(preprocessed_test_data[0])

    normalized_train_data = knn.normalize_data(preprocessed_train_data)
    normalized_val_data = knn.normalize_data(preprocessed_val_data)
    normalized_test_data = knn.normalize_data(preprocessed_test_data)

    # print(normalized_train_data[0])
    # print(normalized_test_data[0])

    knn.fit(normalized_train_data, train_labels)

    # print(normalized_test_data[0])

    # print(normalized_test_data)
    val_predictions = knn.predict(normalized_val_data)
    test_predictions = knn.predict(normalized_test_data)

    # print(predictions[:10])
    # print(test_labels[:10])
    
    # knn.validate(predictions, test_labels)

    save_predictions("val_pred.csv", val_predictions)
    save_predictions("test_pred.csv", test_predictions)
    print("Files saved as 'val_pred.csv' and 'test_pred.csv'.")

if __name__ == "__main__":
    main()