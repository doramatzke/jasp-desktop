#include "correlationbayesianpairsform.h"
#include "ui_correlationbayesianpairsform.h"

#include "widgets/tablemodelvariablesassigned.h"

CorrelationBayesianPairsForm::CorrelationBayesianPairsForm(QWidget *parent) :
	AnalysisForm("CorrelationBayesianPairsForm", parent),
	ui(new Ui::CorrelationBayesianPairsForm)
{
	ui->setupUi(this);

	_availableVariablesModel.setSupportedDropActions(Qt::MoveAction);
	_availableVariablesModel.setSupportedDragActions(Qt::CopyAction);
	_availableVariablesModel.setVariableTypesSuggested(Column::ColumnTypeScale);
	_availableVariablesModel.setVariableTypesAllowed(Column::ColumnTypeScale | Column::ColumnTypeOrdinal | Column::ColumnTypeNominal);

	ui->availableFields->setModel(&_availableVariablesModel);
	ui->availableFields->setDefaultDropAction(Qt::MoveAction);
	ui->availableFields->setDoubleClickTarget(ui->pairs);

	TableModelPairsAssigned *model = new TableModelPairsAssigned(this);
	model->setSource(&_availableVariablesModel);
	model->setVariableTypesSuggested(Column::ColumnTypeScale);
	model->setVariableTypesAllowed(Column::ColumnTypeScale | Column::ColumnTypeOrdinal | Column::ColumnTypeNominal);
	ui->pairs->setModel(model);

	ui->assignButton->setSourceAndTarget(ui->availableFields, ui->pairs);

#ifdef QT_NO_DEBUG
	ui->plotSequentialAnalysisRobustness->hide();
#else
	ui->plotSequentialAnalysisRobustness->setStyleSheet("background-color: pink;");
#endif

	ui->priorWidth->setLabel("Beta* prior width");
}

CorrelationBayesianPairsForm::~CorrelationBayesianPairsForm()
{
	delete ui;
}
