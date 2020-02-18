//
// Copyright (C) 2013-2018 University of Amsterdam
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.
//

import QtQuick 2.8
import QtQuick.Layouts 1.3
import JASP.Controls 1.0
import JASP.Widgets 1.0


Form 
{
    usesJaspResults: true

    IntegerField { name: "sampleSize"; label: qsTr("Sample size") }

    Divider { }

	RadioButtonGroup
	{
        name: "correlationCoefficient"
		title: qsTr("Correlation Coefficient")
		Layout.columnSpan: 2
		RadioButton
		{
            value: "pearsonRho"; label: qsTr("Pearson's rho"); checked: true; childrenOnSameRow: true
            DoubleField { name: "pearsonRhoValue"; defaultValue: 0; min: -1; max: 1 }
		}
		RadioButton
		{
            value: "kendallTau"; label: qsTr("Kendall's tau-b"); childrenOnSameRow: true
            DoubleField { name: "kendallTauValue"; defaultValue: 0; min: -1; max: 1 }
		}
        RadioButton
        {
            value: "spearman"; label: qsTr("Spearman's rho"); childrenOnSameRow: true; debug: true
            DoubleField { name: "rhoSObs"; defaultValue: 0; min: -1; max: 1 }
        }
	}


	RadioButtonGroup
	{
		title: qsTr("Alt. Hypothesis")
        name: "hypothesis"
        RadioButton { value: "correlated";                          label: qsTr("Correlated"); checked: true	}
        RadioButton { value: "correlatedPositively";                label: qsTr("Correlated positively")		}
        RadioButton { value: "correlatedNegatively";                label: qsTr("Correlated negatively")		}
	}

    CheckBox
    {
        name: "ci"; label: qsTr("Credible intervals")
        CIField { name: "ciValue";	label: qsTr("Interval") }
    }

	Group
	{
		title: qsTr("Plots")
		CheckBox
		{
            name: "plotPriorAndPosterior";				label: qsTr("Prior and posterior")
            CheckBox { name: "plotPriorPosteriorAddEstimationInfo";	label: qsTr("Estimation info"); checked: true }
            CheckBox { name: "plotPriorAndPosteriorAdditionalInfo";	label: qsTr("Testing info"); checked: true }
		}
		CheckBox
		{
            name: "plotBayesFactorRobustness";                          label: qsTr("Bayes factor robustness check")
            CheckBox { name: "plotBayesFactorRobustnessAdditionalInfo"; label: qsTr("Additional info"); checked: true }
		}
	}

	BayesFactorType { }

	Group
	{
        title: qsTr("Prior")
        DoubleField { name: "priorWidth";       label: qsTr("Stretched beta prior width");      defaultValue: 1.0; min: 0.003; max: 2; decimals: 3 }
	}
}
